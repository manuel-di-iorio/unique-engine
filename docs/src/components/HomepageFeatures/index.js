import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: 'Simple by Design',
    // Svg: require('@site/static/img/undraw_docusaurus_mountain.svg').default,
    src: require('@site/static/img/headline_simple.png').default,
    description: (
      <>
        Unique Engine is built to make 3D development in GameMaker intuitive, with clean API and no boilerplate. Just focus on your game.
      </>
    ),
  },
  {
    title: 'Modular and Flexible',
    src: require('@site/static/img/headline_puzzle.png').default,
    description: (
      <>
        From rendering to controls, each part of the engine is modular. Customize, extend, or swap components as your game evolves.
      </>
    ),
  },
  {
    title: 'Inspired by the Best',
    src: require('@site/static/img/headline_three.png').default,
    description: (
      <>
        Designed with Three.js in mind, Unique Engine brings modern 3D capabilities to GameMaker in a lightweight, developer-friendly package.
      </>
    ),
  },
];

function Feature({ Svg, src, title, description }) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        {src ?
          <img src={src} className={styles.featureSvg} role="img" /> :
          <Svg className={styles.featureSvg} role="img" />}
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
